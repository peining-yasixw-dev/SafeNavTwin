using System;
using System.IO;
using System.Text;
using UnityEngine;

public class TrialLogger : MonoBehaviour
{
    [Header("Metadata")]
    public string participantId = "P001";
    public string condition = "C1";
    public int trial = 1;

    [Header("Logging")]
    public float sampleHz = 20f;          // 20 Hz
    public string filePrefix = "raydata"; // 输出文件前缀

    [Header("Refs")]
    public Transform agent;               // 拖你的 agent 进来
    public Transform endZone;             // 可选：用于计算到终点距离

    float t0;
    float nextSampleTime;
    bool running;

    StringBuilder raw = new StringBuilder();
    float minForwardHit = float.PositiveInfinity;

    string rawPath;
    string summaryPath;

    void Start()
    {
        if (agent == null) agent = GameObject.Find("agent")?.transform;

        string stamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        string baseName = $"{filePrefix}_{participantId}_{condition}_T{trial}_{stamp}";

        rawPath = Path.Combine(Application.persistentDataPath, baseName + "_raw.csv");
        summaryPath = Path.Combine(Application.persistentDataPath, baseName + "_summary.csv");

        raw.AppendLine("time_s,agent_x,agent_y,agent_z,forward_hit_m");

        t0 = Time.time;
        nextSampleTime = t0;
        running = true;

        Debug.Log($"[LOGGER] raw -> {rawPath}");
        Debug.Log($"[LOGGER] summary -> {summaryPath}");
    }

    void Update()
    {
        if (!running) return;

        // 固定采样频率
        if (Time.time >= nextSampleTime)
        {
            nextSampleTime += 1f / Mathf.Max(1f, sampleHz);

            float t = Time.time - t0;

            // forward raycast
            float hitDist = float.PositiveInfinity;
            Ray ray = new Ray(agent.position, agent.forward);
            if (Physics.Raycast(ray, out RaycastHit hit, 50f))
            {
                hitDist = hit.distance;
                if (hitDist < minForwardHit) minForwardHit = hitDist;

                // 让你“看见”射线（Scene视图里）
                Debug.DrawRay(ray.origin, ray.direction * hitDist, Color.red, 0.2f);
            }

            Vector3 p = agent.position;
            raw.AppendLine($"{t:F3},{p.x:F4},{p.y:F4},{p.z:F4},{(float.IsInfinity(hitDist) ? -1f : hitDist):F4}");
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (!running) return;

        // agent 进 endzone 就结束
        if (other.transform == agent)
        {
            EndTrial("ReachedEnd");
        }
    }

    public void EndTrial(string reason)
    {
        if (!running) return;
        running = false;

        // 写 raw
        File.WriteAllText(rawPath, raw.ToString());

        // 写 summary
        float duration = Time.time - t0;
        string minHitOut = float.IsInfinity(minForwardHit) ? "-1" : minForwardHit.ToString("F4");

        var sb = new StringBuilder();
        sb.AppendLine("participant,condition,trial,duration_s,min_forward_hit_m,end_reason,raw_path");
        sb.AppendLine($"{participantId},{condition},{trial},{duration:F3},{minHitOut},{reason},{rawPath}");
        File.WriteAllText(summaryPath, sb.ToString());

        Debug.Log($"[LOGGER] DONE. duration={duration:F2}s minHit={minHitOut} reason={reason}");
        Debug.Log($"[LOGGER] wrote raw: {rawPath}");
        Debug.Log($"[LOGGER] wrote summary: {summaryPath}");
    }
}
